# frozen_string_literal: true

RSpec.describe Gitlab::Cells::HttpRouter::RoutesSnapshot do
  describe '.example_for' do
    using RSpec::Parameterized::TableSyntax

    where(:case_name, :template, :expected) do
      'a plain route' | '/-/jira_connect/subscriptions/:id' | '/-/jira_connect/subscriptions/foo'
      'an optional segment' | '(/-/jira)/*namespace_id/:project_id' | '/-/jira/foo/bar/foo'
      'an inline format segment' | '/*namespace_id/:project_id/-/archive/*id.:format' | '/foo/bar/foo/-/archive/foo/bar'
      'escaped literal parentheses' |
        '/api/:version/projects/:project_id/packages/nuget/v2/FindPackagesById\(\)' |
        '/api/v4/projects/foo/packages/nuget/v2/FindPackagesById()'
      'the API version placeholder' | '/api/:version/groups/:id/access_requests' | '/api/v4/groups/foo/access_requests'
      'nested optional segments' | '/foo(/:bar(/:baz))' | '/foo/foo/foo'
      'the root path' | '/' | '/'
      'an optional segment that unwraps to an empty path' | '(/)' | '/'
      'duplicate and trailing slashes' | '/foo//:bar/' | '/foo/foo'
      'an unbalanced parenthesis' | '/foo(/:bar' | '/foo(/foo'
    end

    with_them do
      it 'builds a concrete example URL' do
        expect(described_class.example_for(template)).to eq(expected)
      end
    end

    context 'with the dotted substitution values' do
      where(:case_name, :template, :expected) do
        'a named parameter' | '/-/jira_connect/subscriptions/:id' | '/-/jira_connect/subscriptions/john.doe'
        'a wildcard' | '/*namespace_id/:project_id' | '/john.doe/bar/john.doe'
        'no parameter at all' | '/users/sign_in' | '/users/sign_in'
      end

      with_them do
        it 'substitutes dotted values' do
          example = described_class.example_for(
            template,
            param: described_class::DOTTED_PARAM_VALUE,
            glob: described_class::DOTTED_GLOB_VALUE
          )

          expect(example).to eq(expected)
        end
      end
    end
  end

  describe '#routes' do
    subject(:routes) { described_class.new(path_specs: path_specs).routes }

    let(:path_specs) { ['/groups/:id(.:format)'] }

    it 'pairs each template with its example and its adversarial variants' do
      expect(routes.map(&:to_h)).to eq([{
        template: '/groups/:id',
        example: '/groups/foo',
        accepts_format: true,
        dotted_example: '/groups/john.doe'
      }])
    end

    context 'when the path spec carries no format segment' do
      let(:path_specs) { ['/groups/:id'] }

      it 'does not accept a format' do
        expect(routes.first.accepts_format).to be(false)
      end
    end

    context 'when the format segment is inline rather than optional' do
      let(:path_specs) { ['/*namespace_id/:project_id/-/archive/*id.:format'] }

      it 'accepts a format' do
        expect(routes.first.accepts_format).to be(true)
      end
    end

    context 'when the template has no parameter' do
      let(:path_specs) { ['/users/sign_in(.:format)'] }

      it 'omits the dotted example' do
        expect(routes.first.dotted_example).to be_nil
      end
    end

    context 'when the template has a wildcard' do
      let(:path_specs) { ['/*namespace_id/:project_id'] }

      it 'builds the dotted example from the wildcard too' do
        expect(routes.first.dotted_example).to eq('/john.doe/bar/john.doe')
      end
    end

    context 'with routes mounted only in the test environment' do
      let(:path_specs) do
        [
          '/-/view_component/previews',
          '/-/view_component/previews/*path',
          '/_system_test_entrypoint',
          '/groups/:id'
        ]
      end

      it 'excludes them' do
        expect(routes.map(&:template)).to contain_exactly('/groups/:id')
      end
    end

    context 'with duplicate path specs' do
      let(:path_specs) { ['/groups/:id(.:format)', '/groups/:id'] }

      it 'deduplicates them after dropping the format segment' do
        expect(routes.map(&:template)).to contain_exactly('/groups/:id')
      end

      it 'accepts a format, since one of the specs accepts a format' do
        expect(routes.first.accepts_format).to be(true)
      end
    end

    it 'sorts templates' do
      generator = described_class.new(path_specs: ['/zebra', '/apple', '/mango'])

      expect(generator.routes.map(&:template)).to eq(%w[/apple /mango /zebra])
    end
  end

  describe '#to_json_string' do
    subject(:json) { described_class.new(path_specs: path_specs).to_json_string }

    let(:path_specs) { ['/groups/:id(.:format)'] }

    it 'pretty-prints the entries and ends with a newline' do
      expect(json).to eq(<<~JSON)
        [
          {
            "template": "/groups/:id",
            "example": "/groups/foo",
            "acceptsFormat": true,
            "dottedExample": "/groups/john.doe"
          }
        ]
      JSON
    end

    context 'when no variant applies' do
      let(:path_specs) { ['/users/sign_in'] }

      it 'omits the optional keys' do
        expect(json).to eq(<<~JSON)
          [
            {
              "template": "/users/sign_in",
              "example": "/users/sign_in"
            }
          ]
        JSON
      end
    end
  end

  describe '#write!' do
    let(:path) { File.join(Dir.mktmpdir, 'nested', 'gitlab_routes.json') }

    it 'creates the parent directory and writes the snapshot' do
      generator = described_class.new(path_specs: ['/groups/:id'])

      expect(generator.write!(path)).to eq(path)
      expect(File.read(path)).to eq(generator.to_json_string)
    end
  end
end
