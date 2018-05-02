require 'spec_helper'

describe Gitlab::Auth::GroupSaml::GroupLookup do
  let(:query_string) { 'group_path=the-group' }
  let(:path_info) { double }

  def subject(params = {})
    @subject ||= begin
      env = {
        "rack.input" => double,
        'PATH_INFO' => path_info
      }.merge(params)

      described_class.new(env)
    end
  end

  context 'on request path' do
    let(:path_info) { '/users/auth/group_saml' }

    it 'can detect group_path from rack.input body params' do
      subject( 'REQUEST_METHOD' => 'POST', 'rack.input' => StringIO.new(query_string) )

      expect(subject.path).to eq 'the-group'
    end

    it 'can detect group_path from query params' do
      subject( "QUERY_STRING" => query_string )

      expect(subject.path).to eq 'the-group'
    end
  end

  context 'on callback path' do
    let(:path_info) { '/groups/callback-group/-/saml/callback' }

    it 'can extract group_path from PATH_INFO' do
      expect(subject.path).to eq 'callback-group'
    end

    it 'does not allow params to take precedence' do
      subject( "QUERY_STRING" => query_string )

      expect(subject.path).to eq 'callback-group'
    end
  end

  it 'looks up group by path' do
    group = create(:group)
    allow(subject).to receive(:path) { group.path }

    expect(subject.group).to be_a(Group)
  end

  it 'exposes saml_provider' do
    saml_provider = create(:saml_provider)
    allow(subject).to receive(:group) { saml_provider.group }

    expect(subject.saml_provider).to be_a(SamlProvider)
  end
end
