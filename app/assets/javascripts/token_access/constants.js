import { helpPagePath } from '~/helpers/help_page_helper';

export const LIMIT_JWT_ACCESS_SNIPPET = `job_name:
  id_tokens:
    ID_TOKEN_1: # or any other name
      aud: "..." # sub-keyword to configure the token's audience
  secrets:
    TEST_SECRET:
      vault: db/prod
`;

export const OPT_IN_JWT_HELP_LINK = helpPagePath('ci/secrets/id_token_authentication', {
  anchor: 'automatic-id-token-authentication-with-hashicorp-vault',
});
