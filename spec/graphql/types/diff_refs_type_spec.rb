# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DiffRefs'] do
  specify { expect(described_class.graphql_name).to eq('DiffRefs') }

  specify { expect(described_class).to have_graphql_fields(:head_sha, :base_sha, :start_sha).only }

  specify { expect(described_class.fields['headSha'].type).to be_non_null }
  specify { expect(described_class.fields['baseSha'].type).not_to be_non_null }
  specify { expect(described_class.fields['startSha'].type).to be_non_null }
end
