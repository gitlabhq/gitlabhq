# frozen_string_literal: true

require "spec_helper"

RSpec.describe AccessTokensHelper do
  describe "#scope_description" do
    using RSpec::Parameterized::TableSyntax

    where(:prefix, :description_location) do
      :personal_access_token  | [:doorkeeper, :scope_desc]
      :project_access_token   | [:doorkeeper, :project_access_token_scope_desc]
    end

    with_them do
      it { expect(helper.scope_description(prefix)).to eq(description_location) }
    end
  end
end
