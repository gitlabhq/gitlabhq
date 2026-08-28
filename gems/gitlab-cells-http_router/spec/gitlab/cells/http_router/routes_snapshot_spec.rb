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
  end

  describe '#routes' do
    subject(:routes) { described_class.new(path_specs: path_specs).routes }

    let(:path_specs) { ['/groups/:id(.:format)'] }

    it 'pairs each template with its example' do
      expect(routes.map(&:to_h)).to eq([{ template: '/groups/:id', example: '/groups/foo' }])
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
    end

    it 'sorts templates' do
      generator = described_class.new(path_specs: ['/zebra', '/apple', '/mango'])

      expect(generator.routes.map(&:template)).to eq(%w[/apple /mango /zebra])
    end
  end

  describe '#to_json_string' do
    subject(:json) { described_class.new(path_specs: ['/groups/:id(.:format)']).to_json_string }

    it 'pretty-prints the entries and ends with a newline' do
      expect(json).to eq(<<~JSON)
        [
          {
            "template": "/groups/:id",
            "example": "/groups/foo"
          }
        ]
      JSON
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
