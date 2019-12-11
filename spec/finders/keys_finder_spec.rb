# frozen_string_literal: true

require 'spec_helper'

describe KeysFinder do
  subject(:keys_finder) { described_class.new(user, params) }

  let(:user) { create(:user) }
  let(:fingerprint_type) { 'md5' }
  let(:fingerprint) { 'ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1' }

  let(:params) do
    {
      type: fingerprint_type,
      fingerprint: fingerprint
    }
  end

  let!(:key) do
    create(:key, user: user,
      key: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=',
      fingerprint: 'ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1',
      fingerprint_sha256: 'nUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo/lCg'
    )
  end

  context 'with a regular user' do
    it 'raises GitLabAccessDeniedError' do
      expect do
        keys_finder.execute
      end.to raise_error(KeysFinder::GitLabAccessDeniedError)
    end
  end

  context 'with an admin user' do
    let(:user) {create(:admin)}

    context 'with invalid MD5 fingerprint' do
      let(:fingerprint) { '11:11:11:11' }

      it 'raises InvalidFingerprint' do
        expect { keys_finder.execute }
          .to raise_error(KeysFinder::InvalidFingerprint)
      end
    end

    context 'with invalid SHA fingerprint' do
      let(:fingerprint_type) { 'sha256' }
      let(:fingerprint) { 'nUhzNyftwAAKs7HufskYTte2g' }

      it 'raises InvalidFingerprint' do
        expect { keys_finder.execute }
          .to raise_error(KeysFinder::InvalidFingerprint)
      end
    end

    context 'with valid MD5 params' do
      it 'returns key if the fingerprint is found' do
        result = keys_finder.execute

        expect(result).to eq(key)
        expect(key.user).to eq(user)
      end
    end

    context 'with valid SHA256 params' do
      let(:fingerprint) { 'ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1' }

      it 'returns key if the fingerprint is found' do
        result = keys_finder.execute

        expect(result).to eq(key)
        expect(key.user).to eq(user)
      end
    end
  end
end
