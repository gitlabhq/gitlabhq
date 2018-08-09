# frozen_string_literal: true

require 'spec_helper'

describe Geo::PushUser do
  let!(:user) { create(:user) }
  let!(:key) { create(:key, user: user) }

  let(:gl_id) { "key-#{key.id}" }

  subject { described_class.new(gl_id) }

  describe '.needed_headers_provided?' do
    where(:headers) do
      [
        {},
        { 'Geo-GL-Id' => nil },
        { 'Geo-GL-Id' => '' }
      ]
    end

    with_them do
      it 'returns false' do
        expect(described_class.needed_headers_provided?(headers)).to be(false)
      end
    end

    context 'where gl_id is not nil' do
      let(:headers) do
        { 'Geo-GL-Id' => gl_id }
      end

      it 'returns true' do
        expect(described_class.needed_headers_provided?(headers)).to be(true)
      end
    end
  end

  describe '.new_from_headers' do
    where(:headers) do
      [
        {},
        { 'Geo-GL-Id' => nil },
        { 'Geo-GL-Id' => '' }
      ]
    end

    with_them do
      it 'returns false' do
        expect(described_class.new_from_headers(headers)).to be_nil
      end
    end

    context 'where gl_id is not nil' do
      let(:headers) do
        { 'Geo-GL-Id' => gl_id }
      end

      it 'returns an instance of Geo::PushUser' do
        expect(described_class.new_from_headers(headers)).to be_a(described_class)
      end
    end
  end

  describe '#user' do
    context 'with a junk gl_id' do
      let(:gl_id) { "test" }

      it 'returns nil' do
        expect(subject.user).to be_nil
      end
    end

    context 'with an unsupported gl_id type' do
      let(:gl_id) { "user-#{user.id}" }

      it 'returns nil' do
        expect(subject.user).to be_nil
      end
    end

    context 'when the User associated to gl_id matches the User associated to gl_username' do
      it 'returns a User' do
        expect(subject.user).to be_a(User)
      end
    end
  end
end
