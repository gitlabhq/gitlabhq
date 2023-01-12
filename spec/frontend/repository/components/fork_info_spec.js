import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlIcon, GlLink } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/flash';

import ForkInfo, { i18n } from '~/repository/components/fork_info.vue';
import forkDetailsQuery from '~/repository/queries/fork_details.query.graphql';
import { propsForkInfo } from '../mock_data';

jest.mock('~/flash');

describe('ForkInfo component', () => {
  let wrapper;
  let mockResolver;
  const forkInfoError = new Error('Something went wrong');

  Vue.use(VueApollo);

  const createCommitData = ({ ahead = 3, behind = 7 }) => {
    return {
      data: {
        project: { id: '1', forkDetails: { ahead, behind, __typename: 'ForkDetails' } },
      },
    };
  };

  const createComponent = (props = {}, data = {}, isRequestFailed = false) => {
    mockResolver = isRequestFailed
      ? jest.fn().mockRejectedValue(forkInfoError)
      : jest.fn().mockResolvedValue(createCommitData(data));

    wrapper = shallowMountExtended(ForkInfo, {
      apolloProvider: createMockApollo([[forkDetailsQuery, mockResolver]]),
      propsData: { ...propsForkInfo, ...props },
    });
    return waitForPromises();
  };

  const findLink = () => wrapper.findComponent(GlLink);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findDivergenceMessage = () => wrapper.find('.gl-text-secondary');
  const findInaccessibleMessage = () => wrapper.findByTestId('inaccessible-project');
  it('displays a skeleton while loading data', async () => {
    createComponent();
    expect(findSkeleton().exists()).toBe(true);
  });

  it('does not display skeleton when data is loaded', async () => {
    await createComponent();
    expect(findSkeleton().exists()).toBe(false);
  });

  it('renders fork icon', async () => {
    await createComponent();
    expect(findIcon().exists()).toBe(true);
  });

  it('queries the data when sourceName is present', async () => {
    await createComponent();
    expect(mockResolver).toHaveBeenCalled();
  });

  it('does not query the data when sourceName is empty', async () => {
    await createComponent({ sourceName: null });
    expect(mockResolver).not.toHaveBeenCalled();
  });

  it('renders inaccessible message when fork source is not available', async () => {
    await createComponent({ sourceName: '' });
    const message = findInaccessibleMessage();
    expect(message.exists()).toBe(true);
    expect(message.text()).toBe(i18n.inaccessibleProject);
  });

  it('shows source project name with a link to a repo', async () => {
    await createComponent();
    const link = findLink();
    expect(link.text()).toBe(propsForkInfo.sourceName);
    expect(link.attributes('href')).toBe(propsForkInfo.sourcePath);
  });

  it('renders unknown divergence message when divergence is unknown', async () => {
    await createComponent({}, { ahead: null, behind: null });
    expect(findDivergenceMessage().text()).toBe(i18n.unknown);
  });

  it('shows correct divergence message when data is present', async () => {
    await createComponent();
    expect(findDivergenceMessage().text()).toMatchInterpolatedText(
      '7 commits behind, 3 commits ahead of the upstream repository.',
    );
  });

  it('renders up to date message when divergence is unknown', async () => {
    await createComponent({}, { ahead: 0, behind: 0 });
    expect(findDivergenceMessage().text()).toBe(i18n.upToDate);
  });

  it('renders commits ahead message', async () => {
    await createComponent({}, { behind: 0 });
    expect(findDivergenceMessage().text()).toBe('3 commits ahead of the upstream repository.');
  });

  it('renders commits behind message', async () => {
    await createComponent({}, { ahead: 0 });

    expect(findDivergenceMessage().text()).toBe('7 commits behind the upstream repository.');
  });

  it('renders alert with error message when request fails', async () => {
    await createComponent({}, {}, true);
    expect(createAlert).toHaveBeenCalledWith({
      message: i18n.error,
      captureError: true,
      error: forkInfoError,
    });
  });
});
