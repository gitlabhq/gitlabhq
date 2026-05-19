import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CreatedPersonalAccessToken from '~/personal_access_tokens/components/created_personal_access_token.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

describe('CreatedPersonalAccessToken', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(CreatedPersonalAccessToken, {
      propsData: {
        token: 'xx',
        href: '/-/personal_access_tokens',
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findDoneButton = () => wrapper.findComponent(GlButton);
  const findInputCopyToggleVisibility = () => wrapper.findComponent(InputCopyToggleVisibility);

  beforeEach(() => {
    createComponent();
  });

  it('renders crud component', () => {
    expect(findCrudComponent().props('title')).toBe('Token details');
  });

  it('renders the page heading', () => {
    expect(findPageHeading().props('heading')).toBe('Your new token has been created');
  });

  it('renders the input copy toggle visibility component', () => {
    expect(findInputCopyToggleVisibility().props()).toMatchObject({
      value: 'xx',
      readonly: true,
      size: 'xl',
    });
  });

  it('renders a disabled `done` button', () => {
    expect(findDoneButton().text()).toBe('Done');
    expect(findDoneButton().props()).toMatchObject({
      disabled: true,
      href: '/-/personal_access_tokens',
    });
  });

  it('enables the `done` button when the copy button is clicked', async () => {
    await findInputCopyToggleVisibility().vm.$emit('copied');

    expect(findDoneButton().props('disabled')).toBe(false);
  });
});
