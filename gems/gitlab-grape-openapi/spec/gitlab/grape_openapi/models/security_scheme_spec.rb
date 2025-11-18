# frozen_string_literal: true

RSpec.describe Gitlab::GrapeOpenapi::Models::SecurityScheme do
  describe 'constants' do
    it 'defines valid types' do
      expect(described_class::VALID_TYPES).to eq(%w[apiKey http oauth2 openIdConnect])
    end

    it 'defines valid in values' do
      expect(described_class::VALID_IN_VALUES).to eq(%w[query header cookie])
    end

    it 'defines valid HTTP schemes' do
      expect(described_class::VALID_HTTP_SCHEMES).to eq(%w[basic bearer oauth])
    end
  end

  describe '#initialize' do
    context 'with invalid type' do
      it 'raises ArgumentError for invalid type' do
        expect { described_class.new(type: 'invalid') }
          .to raise_error(ArgumentError, "Invalid type: invalid. Must be one of: apiKey, http, oauth2, openIdConnect")
      end
    end

    context 'with apiKey type' do
      it 'creates instance with required parameters' do
        scheme = described_class.new(type: 'apiKey', name: 'api_key', in: 'header')

        expect(scheme.type).to eq('apiKey')
        expect(scheme.name).to eq('api_key')
        expect(scheme.in).to eq('header')
      end

      it 'accepts description parameter' do
        scheme = described_class.new(type: 'apiKey', name: 'api_key', in: 'header', description: 'API Key auth')

        expect(scheme.description).to eq('API Key auth')
      end

      it 'raises ArgumentError when name is missing' do
        expect { described_class.new(type: 'apiKey', in: 'header') }
          .to raise_error(ArgumentError, "name is required for apiKey type")
      end

      it 'raises ArgumentError when in is missing' do
        expect { described_class.new(type: 'apiKey', name: 'api_key') }
          .to raise_error(ArgumentError, "in is required for apiKey type")
      end

      it 'raises ArgumentError for invalid in value' do
        expect { described_class.new(type: 'apiKey', name: 'api_key', in: 'invalid') }
          .to raise_error(ArgumentError, "Invalid 'in' value: invalid. Must be one of: query, header, cookie")
      end

      %w[query header cookie].each do |in_value|
        it "accepts valid in value: #{in_value}" do
          scheme = described_class.new(type: 'apiKey', name: 'api_key', in: in_value)
          expect(scheme.in).to eq(in_value)
        end
      end
    end

    context 'with http type' do
      it 'creates instance with required parameters' do
        scheme = described_class.new(type: 'http', scheme: 'basic')

        expect(scheme.type).to eq('http')
        expect(scheme.scheme).to eq('basic')
      end

      it 'raises ArgumentError when scheme is missing' do
        expect { described_class.new(type: 'http') }
          .to raise_error(ArgumentError, "scheme is required for http type")
      end

      it 'raises ArgumentError for invalid HTTP scheme' do
        expect { described_class.new(type: 'http', scheme: 'invalid') }
          .to raise_error(ArgumentError, "Invalid HTTP scheme: invalid. Common values: basic, bearer, oauth")
      end

      %w[basic bearer oauth].each do |scheme_value|
        it "accepts valid HTTP scheme: #{scheme_value}" do
          scheme = described_class.new(type: 'http', scheme: scheme_value)
          expect(scheme.scheme).to eq(scheme_value)
        end
      end

      it 'accepts case-insensitive HTTP schemes' do
        scheme = described_class.new(type: 'http', scheme: 'BASIC')
        expect(scheme.scheme).to eq('BASIC')
      end

      it 'sets bearer_format when scheme is bearer' do
        scheme = described_class.new(type: 'http', scheme: 'bearer', bearer_format: 'JWT')

        expect(scheme.bearer_format).to eq('JWT')
      end

      it 'does not set bearer_format when scheme is not bearer' do
        scheme = described_class.new(type: 'http', scheme: 'basic', bearer_format: 'JWT')

        expect(scheme.bearer_format).to be_nil
      end
    end

    context 'with oauth2 type' do
      let(:valid_flows) do
        {
          implicit: {
            authorizationUrl: 'https://example.com/auth',
            scopes: { read: 'Read access' }
          }
        }
      end

      it 'creates instance with required parameters' do
        scheme = described_class.new(type: 'oauth2', flows: valid_flows)

        expect(scheme.type).to eq('oauth2')
        expect(scheme.flows).to eq(valid_flows)
      end

      it 'raises ArgumentError when flows is missing' do
        expect { described_class.new(type: 'oauth2') }
          .to raise_error(ArgumentError, "flows is required for oauth2 type")
      end

      it 'raises ArgumentError when flows is not a Hash' do
        expect { described_class.new(type: 'oauth2', flows: 'invalid') }
          .to raise_error(ArgumentError, "flows must be a Hash")
      end

      it 'raises ArgumentError for invalid flow type' do
        invalid_flows = { invalid_flow: {} }

        expect { described_class.new(type: 'oauth2', flows: invalid_flows) }
          .to raise_error(ArgumentError)
      end

      context 'with implicit flow' do
        it 'validates required fields' do
          expect { described_class.new(type: 'oauth2', flows: { implicit: {} }) }
            .to raise_error(ArgumentError, "authorizationUrl required for implicit flow")

          expect { described_class.new(type: 'oauth2', flows: { implicit: { authorizationUrl: 'url' } }) }
            .to raise_error(ArgumentError, "scopes required for implicit flow")
        end

        it 'accepts valid implicit flow' do
          flows = { implicit: { authorizationUrl: 'url', scopes: {} } }
          scheme = described_class.new(type: 'oauth2', flows: flows)

          expect(scheme.flows).to eq(flows)
        end
      end

      context 'with password flow' do
        it 'validates required fields' do
          expect { described_class.new(type: 'oauth2', flows: { password: {} }) }
            .to raise_error(ArgumentError, "tokenUrl required for password flow")

          expect { described_class.new(type: 'oauth2', flows: { password: { tokenUrl: 'url' } }) }
            .to raise_error(ArgumentError, "scopes required for password flow")
        end

        it 'accepts valid password flow' do
          flows = { password: { tokenUrl: 'url', scopes: {} } }
          scheme = described_class.new(type: 'oauth2', flows: flows)

          expect(scheme.flows).to eq(flows)
        end
      end

      context 'with clientCredentials flow' do
        it 'validates required fields' do
          expect { described_class.new(type: 'oauth2', flows: { clientCredentials: {} }) }
            .to raise_error(ArgumentError, "tokenUrl required for clientCredentials flow")

          expect { described_class.new(type: 'oauth2', flows: { clientCredentials: { tokenUrl: 'url' } }) }
            .to raise_error(ArgumentError, "scopes required for clientCredentials flow")
        end

        it 'accepts valid clientCredentials flow' do
          flows = { clientCredentials: { tokenUrl: 'url', scopes: {} } }
          scheme = described_class.new(type: 'oauth2', flows: flows)

          expect(scheme.flows).to eq(flows)
        end
      end

      context 'with authorizationCode flow' do
        it 'validates required fields' do
          expect { described_class.new(type: 'oauth2', flows: { authorizationCode: {} }) }
            .to raise_error(ArgumentError, "authorizationUrl required for authorizationCode flow")

          expect { described_class.new(type: 'oauth2', flows: { authorizationCode: { authorizationUrl: 'url' } }) }
            .to raise_error(ArgumentError, "tokenUrl required for authorizationCode flow")

          expect do
            described_class.new(
              type: 'oauth2', flows: { authorizationCode: { authorizationUrl: 'url', tokenUrl: 'token' } }
            )
          end.to raise_error(ArgumentError, "scopes required for authorizationCode flow")
        end

        it 'accepts valid authorizationCode flow' do
          flows = { authorizationCode: { authorizationUrl: 'auth_url', tokenUrl: 'token_url', scopes: {} } }
          scheme = described_class.new(type: 'oauth2', flows: flows)

          expect(scheme.flows).to eq(flows)
        end
      end
    end

    context 'with openIdConnect type' do
      it 'creates instance with required parameters' do
        scheme = described_class.new(type: 'openIdConnect', open_id_connect_url: 'https://example.com/.well-known/openid_configuration')

        expect(scheme.type).to eq('openIdConnect')
        expect(scheme.open_id_connect_url).to eq('https://example.com/.well-known/openid_configuration')
      end

      it 'raises ArgumentError when open_id_connect_url is missing' do
        expect { described_class.new(type: 'openIdConnect') }
          .to raise_error(ArgumentError, "open_id_connect_url is required for openIdConnect type")
      end
    end
  end

  describe '#to_h' do
    context 'with apiKey type' do
      it 'returns correct hash structure' do
        scheme = described_class.new(type: 'apiKey', name: 'X-API-Key', in: 'header', description: 'API Key')

        expected = {
          'type' => 'apiKey',
          'description' => 'API Key',
          'name' => 'X-API-Key',
          'in' => 'header'
        }

        expect(scheme.to_h).to eq(expected)
      end

      it 'omits description when not provided' do
        scheme = described_class.new(type: 'apiKey', name: 'X-API-Key', in: 'header')

        expected = {
          'type' => 'apiKey',
          'name' => 'X-API-Key',
          'in' => 'header'
        }

        expect(scheme.to_h).to eq(expected)
      end
    end

    context 'with http type' do
      it 'returns correct hash structure for basic auth' do
        scheme = described_class.new(type: 'http', scheme: 'basic', description: 'Basic Auth')

        expected = {
          'type' => 'http',
          'description' => 'Basic Auth',
          'scheme' => 'basic'
        }

        expect(scheme.to_h).to eq(expected)
      end

      it 'includes bearerFormat for bearer scheme' do
        scheme = described_class.new(type: 'http', scheme: 'bearer', bearer_format: 'JWT')

        expected = {
          'type' => 'http',
          'scheme' => 'bearer',
          'bearerFormat' => 'JWT'
        }

        expect(scheme.to_h).to eq(expected)
      end

      it 'omits bearerFormat when not provided' do
        scheme = described_class.new(type: 'http', scheme: 'bearer')

        expected = {
          'type' => 'http',
          'scheme' => 'bearer'
        }

        expect(scheme.to_h).to eq(expected)
      end
    end

    context 'with oauth2 type' do
      it 'returns correct hash structure with flows' do
        flows = {
          implicit: {
            authorizationUrl: 'https://example.com/auth',
            scopes: { read: 'Read access', write: 'Write access' }
          },
          authorizationCode: {
            authorizationUrl: 'https://example.com/auth',
            tokenUrl: 'https://example.com/token',
            refreshUrl: 'https://example.com/refresh',
            scopes: { admin: 'Admin access' }
          }
        }

        scheme = described_class.new(type: 'oauth2', flows: flows)

        expected = {
          'type' => 'oauth2',
          'flows' => {
            'implicit' => {
              'authorizationUrl' => 'https://example.com/auth',
              'scopes' => { read: 'Read access', write: 'Write access' }
            },
            'authorizationCode' => {
              'authorizationUrl' => 'https://example.com/auth',
              'tokenUrl' => 'https://example.com/token',
              'refreshUrl' => 'https://example.com/refresh',
              'scopes' => { admin: 'Admin access' }
            }
          }
        }

        expect(scheme.to_h).to eq(expected)
      end
    end

    context 'with openIdConnect type' do
      it 'returns correct hash structure' do
        scheme = described_class.new(
          type: 'openIdConnect',
          open_id_connect_url: 'https://example.com/.well-known/openid_configuration',
          description: 'OpenID Connect'
        )

        expected = {
          'type' => 'openIdConnect',
          'description' => 'OpenID Connect',
          'openIdConnectUrl' => 'https://example.com/.well-known/openid_configuration'
        }

        expect(scheme.to_h).to eq(expected)
      end
    end
  end
end
