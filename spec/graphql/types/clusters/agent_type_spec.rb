# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ClusterAgent'] do
  let(:fields) { %i[created_at created_by_user id name project updated_at tokens web_path connections activity_events] }

  it { expect(described_class.graphql_name).to eq('ClusterAgent') }

  it { expect(described_class).to require_graphql_authorizations(:read_cluster_agent) }

  it { expect(described_class).to include_graphql_fields(*fields) }
end
