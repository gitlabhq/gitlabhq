import { AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION, AWS_SECRET_ACCESS_KEY } from '../constants';

export const awsTokens = {
  [AWS_ACCESS_KEY_ID]: {
    name: AWS_ACCESS_KEY_ID,
  },
  [AWS_DEFAULT_REGION]: {
    name: AWS_DEFAULT_REGION,
  },
  [AWS_SECRET_ACCESS_KEY]: {
    name: AWS_SECRET_ACCESS_KEY,
  },
};

export const awsTokenList = Object.keys(awsTokens);
