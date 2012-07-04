require 'spec_helper'

describe Gitlab::API do
  let(:user) { Factory :user }

  describe "GET /users" do
    it "should return authentication error" do
      get "#{api_prefix}/users"
      response.status.should == 401
    end

    describe "authenticated GET /users" do
      it "should return an array of users" do
        get "#{api_prefix}/users?private_token=#{user.private_token}"
        response.status.should == 200
        json_response.should be_an Array
        json_response.first['email'].should == user.email
      end
    end
  end

  describe "GET /users/:id" do
    it "should return a user by id" do
      get "#{api_prefix}/users/#{user.id}?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['email'].should == user.email
    end
  end

  describe "GET /user" do
    it "should return current user" do
      get "#{api_prefix}/user?private_token=#{user.private_token}"
      response.status.should == 200
      json_response['email'].should == user.email
    end
  end
end
