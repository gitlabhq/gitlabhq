import { MEMBER_ACCESS_LEVEL_PROPERTY_NAME } from '~/members/constants';
import { baseRequestFormatter } from '~/members/utils';
import { GROUP_MEMBER_BASE_PROPERTY_NAME } from './constants';

export const groupMemberRequestFormatter = baseRequestFormatter(
  GROUP_MEMBER_BASE_PROPERTY_NAME,
  MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
);
