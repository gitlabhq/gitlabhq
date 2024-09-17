import { GlSprintf, GlLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import RunnerCreatedAt from '~/ci/runner/components/runner_created_at.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerCreatedAt', () => {
  let wrapper;

  const createWrapper = ({ runner = {} } = {}) => {
    wrapper = mountExtended(RunnerCreatedAt, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        GlSprintf,
        TimeAgo,
        UserAvatarLink,
      },
    });
  };

  const findTimeAgo = () => wrapper.findComponent(TimeAgo);
  const findLink = () => wrapper.findComponent(GlLink);

  const expectUserLink = (createdBy) => {
    const { id, name, avatarUrl, webUrl, username } = createdBy;

    expect(findLink().text()).toBe(name);
    expect(findLink().attributes('href')).toBe(webUrl);
    expect({ ...findLink().element.dataset }).toEqual({
      avatarUrl,
      name,
      userId: `${getIdFromGraphQLId(id)}`,
      username,
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('shows creation time and creator', () => {
    expect(wrapper.text()).toMatchInterpolatedText(
      `Created by ${mockRunner.createdBy.name} ${findTimeAgo().text()}`,
    );

    expectUserLink(mockRunner.createdBy);
    expect(findTimeAgo().props('time')).toBe(mockRunner.createdAt);
  });

  it('shows creation time with no creator', () => {
    createWrapper({
      runner: {
        createdBy: null,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText(`Created ${findTimeAgo().text()}`);

    expect(findLink().exists()).toBe(false);
    expect(findTimeAgo().props('time')).toBe(mockRunner.createdAt);
  });

  it('shows creator with no creation time', () => {
    createWrapper({
      runner: {
        createdAt: null,
      },
    });

    expect(wrapper.text()).toMatchInterpolatedText(`Created by ${mockRunner.createdBy.name}`);

    expectUserLink(mockRunner.createdBy);
    expect(findTimeAgo().exists()).toBe(false);
  });

  it('shows no creation information', () => {
    createWrapper({
      runner: {
        createdBy: null,
        createdAt: null,
      },
    });

    expect(wrapper.find('*').exists()).toBe(false);
  });
});
