import { __ } from '~/locale';

import { AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY } from '../constants';

export const awsTokens = {
  [AWS_ACCESS_KEY_ID]: {
    name: AWS_ACCESS_KEY_ID,
    /* Checks for exactly twenty characters that match key.
       Based on greps suggested by Amazon at:
       https://aws.amazon.com/blogs/security/a-safer-way-to-distribute-aws-credentials-to-ec2/
    */
    validation: val => /^[A-Za-z0-9]{20}$/.test(val),
    invalidMessage: __('This variable does not match the expected pattern.'),
  },
  [AWS_DEFAULT_REGION]: {
    name: AWS_DEFAULT_REGION,
  },
  [AWS_SECRET_ACCESS_KEY]: {
    name: AWS_SECRET_ACCESS_KEY,
    /* Checks for exactly forty characters that match secret.
       Based on greps suggested by Amazon at:
       https://aws.amazon.com/blogs/security/a-safer-way-to-distribute-aws-credentials-to-ec2/
    */
    validation: val => /^[A-Za-z0-9/+=]{40}$/.test(val),
    invalidMessage: __('This variable does not match the expected pattern.'),
  },
};

export const awsTokenList = Object.keys(awsTokens);
