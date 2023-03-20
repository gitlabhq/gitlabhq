import { mount } from '@vue/test-utils';
import ShaMismatch from '~/vue_merge_request_widget/components/states/sha_mismatch.vue';
import { I18N_SHA_MISMATCH } from '~/vue_merge_request_widget/i18n';

function createComponent({ path = '' } = {}) {
  return mount(ShaMismatch, {
    propsData: {
      mr: {
        mergeRequestDiffsPath: path,
      },
    },
  });
}

describe('ShaMismatch', () => {
  let wrapper;
  const findActionButton = () => wrapper.find('[data-testid="action-button"]');

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('should render warning message', () => {
    expect(wrapper.text()).toContain('Merge blocked: new changes were just added.');
  });

  it('action button should have correct label', () => {
    expect(findActionButton().text()).toBe(I18N_SHA_MISMATCH.actionButtonLabel);
  });

  it('action button should link to the diff path', () => {
    const DIFF_PATH = '/gitlab-org/gitlab-test/-/merge_requests/6/diffs';

    wrapper = createComponent({ path: DIFF_PATH });

    expect(findActionButton().attributes('href')).toBe(DIFF_PATH);
  });
});
