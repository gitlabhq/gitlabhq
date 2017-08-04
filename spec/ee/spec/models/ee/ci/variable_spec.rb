require 'spec_helper'

describe Ci::Variable do
  subject { build(:ci_variable) }

  it { is_expected.to allow_value('*').for(:environment_scope) }
  it { is_expected.to allow_value('review/*').for(:environment_scope) }
  it { is_expected.not_to allow_value('').for(:environment_scope) }

  it do
    is_expected.to validate_uniqueness_of(:key)
      .scoped_to(:project_id, :environment_scope)
  end
end
