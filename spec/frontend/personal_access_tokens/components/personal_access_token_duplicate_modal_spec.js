import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import PersonalAccessTokenDuplicateModal from '~/personal_access_tokens/components/personal_access_token_duplicate_modal.vue';
import { mockTokens } from '../mock_data';

const GRANULAR_NEW_URL = '/user_settings/personal_access_tokens/granular/new';

describe('PersonalAccessTokenDuplicateModal', () => {
  useMockLocationHelper();

  let wrapper;

  const mockToken = mockTokens[0];

  const createComponent = ({ token = mockToken, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenDuplicateModal, {
      propsData: { token },
      provide: {
        accessTokenGranularNewUrl: GRANULAR_NEW_URL,
      },
      stubs,
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  it('is not visible when token is null', () => {
    createComponent({ token: null });

    expect(findModal().props('visible')).toBe(false);
  });

  it('uses a static modal id', () => {
    createComponent();

    expect(findModal().props('modalId')).toBe('duplicate-token-modal');
  });

  it('does not navigate when token is null and primary is emitted', () => {
    createComponent({ token: null });
    findModal().vm.$emit('primary');

    expect(window.location.href).not.toContain(GRANULAR_NEW_URL);
  });

  it('is visible when token is provided', () => {
    createComponent();

    expect(findModal().props('visible')).toBe(true);
  });

  it('renders title with token name', () => {
    createComponent();

    expect(findModal().props('title')).toBe("Duplicate 'Token 1'?");
  });

  it('shows description with bold token name', () => {
    createComponent({ stubs: { GlSprintf } });

    expect(wrapper.text()).toContain(
      `A new fine-grained token form will open with the resource and permissions from ${mockToken.name} pre-filled. ${mockToken.name} will not be affected.`,
    );
    expect(wrapper.find('b').text()).toBe(mockToken.name);
  });

  it('configures primary action as confirm variant', () => {
    createComponent();

    expect(findModal().props('actionPrimary')).toMatchObject({
      text: 'Duplicate',
      attributes: { variant: 'confirm' },
    });
  });

  it('emits cancel when modal is hidden', () => {
    createComponent();

    findModal().vm.$emit('hidden');

    expect(wrapper.emitted('cancel')).toHaveLength(1);
  });

  it('redirects to pre-populated form on confirm', () => {
    createComponent();
    findModal().vm.$emit('primary');

    expect(window.location.href).toContain(GRANULAR_NEW_URL);
    expect(window.location.href).toContain('source_token_id=1');
  });
});
