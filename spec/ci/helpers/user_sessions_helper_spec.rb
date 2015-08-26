require 'spec_helper'

describe UserSessionsHelper do
  describe :generate_oauth_hmac do
    let (:salt) { 'a' }
    let (:salt2) { 'b' }
    let (:return_to) { 'b' }

    it 'should return null if return_to is also null' do
      generate_oauth_hmac(salt, nil).should be_nil
    end

    it 'should return not null if return_to is also not null' do
      generate_oauth_hmac(salt, return_to).should_not be_nil
    end

    it 'should return different hmacs for different salts' do
      secret1 = generate_oauth_hmac(salt, return_to)
      secret2 = generate_oauth_hmac(salt2, return_to)
      secret1.should_not eq(secret2)
    end
  end

  describe :generate_oauth_state do
    let (:return_to) { 'b' }

    it 'should return null if return_to is also null' do
      generate_oauth_state(nil).should be_nil
    end

    it 'should return two different states for same return_to' do
      state1 = generate_oauth_state(return_to)
      state2 = generate_oauth_state(return_to)
      state1.should_not eq(state2)
    end
  end

  describe :get_ouath_state_return_to do
    let (:return_to) { 'a' }
    let (:state) { generate_oauth_state(return_to) }

    it 'should return return_to' do
      get_ouath_state_return_to(state).should eq(return_to)
    end
  end

  describe :is_oauth_state_valid? do
    let (:return_to) { 'a' }
    let (:state) { generate_oauth_state(return_to) }
    let (:forged) { "forged#{state}" }
    let (:invalid) { 'aa' }
    let (:invalid2) { 'aa:bb' }
    let (:invalid3) { 'aa:bb:' }

    it 'should validate oauth state' do
      is_oauth_state_valid?(state).should be_true
    end

    it 'should not validate forged state' do
      is_oauth_state_valid?(forged).should be_false
    end

    it 'should not validate invalid state' do
      is_oauth_state_valid?(invalid).should be_false
      is_oauth_state_valid?(invalid2).should be_false
      is_oauth_state_valid?(invalid3).should be_false
    end
  end
end
