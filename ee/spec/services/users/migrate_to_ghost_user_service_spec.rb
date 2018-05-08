require 'spec_helper'

describe Users::MigrateToGhostUserService do
  context 'epics'  do
    let!(:user)      { create(:user) }
    let(:service)    { described_class.new(user) }

    context 'deleted user is present as both author and edited_user' do
      include_examples "migrating a deleted user's associated records to the ghost user", Epic, [:author, :last_edited_by] do
        let(:created_record) do
          create(:epic, group: create(:group), author: user, last_edited_by: user)
        end
      end
    end

    context 'deleted user is present only as edited_user' do
      include_examples "migrating a deleted user's associated records to the ghost user", Epic, [:last_edited_by] do
        let(:created_record) { create(:epic, group: create(:group), author: create(:user), last_edited_by: user) }
      end
    end
  end

  context 'vulnerability_feedback'  do
    let!(:user)      { create(:user) }
    let(:service)    { described_class.new(user) }

    include_examples "migrating a deleted user's associated records to the ghost user", VulnerabilityFeedback, [:author] do
      let(:created_record) { create(:vulnerability_feedback, author: user) }
    end
  end
end
