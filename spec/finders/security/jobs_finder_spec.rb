# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::JobsFinder do
  it 'is an abstract class that does not permit instantiation' do
    expect { described_class.new(pipeline: nil) }.to raise_error(
      NotImplementedError,
      'This is an abstract class, please instantiate its descendants'
    )
  end

  describe '.allowed_job_types' do
    it 'must be implemented by child classes' do
      expect { described_class.allowed_job_types }.to raise_error(
        NotImplementedError,
        'allowed_job_types must be overwritten to return an array of job types'
      )
    end
  end
end
