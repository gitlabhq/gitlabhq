import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CreatedPersonalAccessToken from '~/personal_access_tokens/components/created_personal_access_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

describe('CreatedPersonalAccessToken', () => {
  let wrapper;

  const tokenValue = 'xx';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CreatedPersonalAccessToken, {
      propsData: {
        value: tokenValue,
        ...props,
      },
      provide: {
        accessTokenTableUrl: '/-/personal_access_tokens',
      },
    });
  };

  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  beforeEach(() => {
    createComponent();
  });

  it('renders the page heading', () => {
    expect(findPageHeading().exists()).toBe(true);
    expect(findPageHeading().props('heading')).toBe('Your new token has been created');

    expect(findPageHeading().text()).toContain(
      "Make sure you copy your token - you won't be able to access it again.",
    );
  });

  it('renders the input copy toggle visibility component', () => {
    expect(findInputCopyToggleVisibility().exists()).toBe(true);

    expect(findInputCopyToggleVisibility().props()).toMatchObject({
      value: tokenValue,
      readonly: true,
      size: 'xl',
      showCopyButton: false,
      formInputGroupProps: {
        'data-testid': 'created-personal-access-token-field',
        autocomplete: 'off',
      },
    });

    expect(findInputCopyToggleVisibility().attributes()).toMatchObject({
      'aria-label': 'Your personal access token',
      'label-for': 'created-personal-access-token-field',
    });
  });

  it('renders clipboard button', () => {
    expect(findClipboardButton().exists()).toBe(true);
    expect(findClipboardButton().props()).toMatchObject({
      text: tokenValue,
      title: 'Copy token',
    });
  });

  it('renders a disabled `done` button', () => {
    expect(findDoneButton().exists()).toBe(true);
    expect(findDoneButton().text()).toBe('Done');
    expect(findDoneButton().attributes('disabled')).toBeDefined();
    expect(findDoneButton().attributes('href')).toBe('/-/personal_access_tokens');
  });

  it('enables the `done` button when the copy button is clicked', async () => {
    await findClipboardButton().vm.$emit('click');

    expect(findDoneButton().attributes('disabled')).toBeUndefined();
  });
});
