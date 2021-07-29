# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'read-only message' do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when database is read-only' do
    before do
      allow(Gitlab::Database.main).to receive(:read_only?).and_return(true)
    end

    it_behaves_like 'Read-only instance', /You are on a read\-only GitLab instance./
  end

  context 'when database is in read-write mode' do
    before do
      allow(Gitlab::Database.main).to receive(:read_only?).and_return(false)
    end

    it_behaves_like 'Read-write instance', /You are on a read\-only GitLab instance./
  end
end
