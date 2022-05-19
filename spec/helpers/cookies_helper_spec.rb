# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CookiesHelper do
  describe '#set_secure_cookie' do
    it 'creates an encrypted cookie with expected attributes' do
      stub_config_setting(https: true)
      expiration = 1.month.from_now
      key = :secure_cookie
      value = 'secure value'

      expect_next_instance_of(ActionDispatch::Cookies::EncryptedKeyRotatingCookieJar) do |instance|
        expect(instance).to receive(:[]=).with(key, { httponly: true, secure: true, expires: expiration, value: value })
      end

      helper.set_secure_cookie(key, value, httponly: true, expires: expiration, type: CookiesHelper::COOKIE_TYPE_ENCRYPTED)
    end

    it 'creates a permanent cookie with expected attributes' do
      key = :permanent_cookie
      value = 'permanent value'

      expect_next_instance_of(ActionDispatch::Cookies::PermanentCookieJar) do |instance|
        expect(instance).to receive(:[]=).with(key, { httponly: false, secure: false, expires: nil, value: value })
      end

      helper.set_secure_cookie(key, value, type: CookiesHelper::COOKIE_TYPE_PERMANENT)
    end

    it 'creates a regular cookie with expected attributes' do
      key = :regular_cookie
      value = 'regular value'

      expect_next_instance_of(ActionDispatch::Cookies::CookieJar) do |instance|
        expect(instance).to receive(:[]=).with(key, { httponly: false, secure: false, expires: nil, value: value })
      end

      helper.set_secure_cookie(key, value)
    end
  end
end
