import { MEMBER_ACCESS_LEVEL_PROPERTY_NAME } from '~/members/constants';
import { baseRequestFormatter } from '~/members/utils';
import { PROJECT_MEMBER_BASE_PROPERTY_NAME } from './constants';

export const projectMemberRequestFormatter = baseRequestFormatter(
  PROJECT_MEMBER_BASE_PROPERTY_NAME,
  MEMBER_ACCESS_LEVEL_PROPERTY_NAME,
);
