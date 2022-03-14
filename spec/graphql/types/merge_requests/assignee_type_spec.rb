# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequestAssignee'] do
  it_behaves_like "a user type with merge request interaction type"
end
