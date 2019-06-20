require 'spec_helper'

describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Issue) }

  it { expect(described_class.graphql_name).to eq('Issue') }

  it { expect(described_class).to require_graphql_authorizations(:read_issue) }

  it { expect(described_class.interfaces).to include(Types::Notes::NoteableType.to_graphql) }

  it 'has specific fields' do
    fields = %i[title_html description_html relative_position web_path web_url
                reference]

    fields.each do |field_name|
      expect(described_class).to have_graphql_field(field_name)
    end
  end
end
