import Vuex from 'vuex';
import { shallowMount } from '@vue/test-utils';
import { getJSONFixture } from 'helpers/fixtures';
import ReleaseShowApp from '~/releases/components/app_show.vue';
import ReleaseSkeletonLoader from '~/releases/components/release_skeleton_loader.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

const originalRelease = getJSONFixture('api/releases/release.json');

describe('Release show component', () => {
  let wrapper;
  let release;
  let actions;

  beforeEach(() => {
    release = convertObjectPropsToCamelCase(originalRelease);
  });

  const factory = state => {
    actions = {
      fetchRelease: jest.fn(),
    };

    const store = new Vuex.Store({
      modules: {
        detail: {
          namespaced: true,
          actions,
          state,
        },
      },
    });

    wrapper = shallowMount(ReleaseShowApp, { store });
  };

  const findLoadingSkeleton = () => wrapper.find(ReleaseSkeletonLoader);
  const findReleaseBlock = () => wrapper.find(ReleaseBlock);

  it('calls fetchRelease when the component is created', () => {
    factory({ release });
    expect(actions.fetchRelease).toHaveBeenCalledTimes(1);
  });

  it('shows a loading skeleton and hides the release block while the API call is in progress', () => {
    factory({ isFetchingRelease: true });
    expect(findLoadingSkeleton().exists()).toBe(true);
    expect(findReleaseBlock().exists()).toBe(false);
  });

  it('hides the loading skeleton and shows the release block when the API call finishes successfully', () => {
    factory({ isFetchingRelease: false });
    expect(findLoadingSkeleton().exists()).toBe(false);
    expect(findReleaseBlock().exists()).toBe(true);
  });

  it('hides both the loading skeleton and the release block when the API call fails', () => {
    factory({ fetchError: new Error('Uh oh') });
    expect(findLoadingSkeleton().exists()).toBe(false);
    expect(findReleaseBlock().exists()).toBe(false);
  });
});
