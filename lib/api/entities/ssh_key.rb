# frozen_string_literal: true

module API
  module Entities
    class SSHKey < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :title, documentation: { type: 'string', example: 'Sample key 25' }
      expose :created_at, documentation: { type: 'dateTime', example: '2015-09-03T07:24:44.627Z' }
      expose :expires_at, documentation: { type: 'dateTime', example: '2020-09-03T07:24:44.627Z' }
      expose :publishable_key, as: :key, documentation:
        { type: 'string',
          example: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6Yjz\
      GGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCdd\
      NaP0L+hM7zhFNzjFvpaMgJw0=' }
      expose :usage_type, documentation: { type: 'string', example: 'auth' }
    end
  end
end
