import { shallowMount } from '@vue/test-utils';
import { GlPopover, GlButton, GlSprintf, GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import NavigationPopover from '~/attention_requests/components/navigation_popover.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

let wrapper;
let dismiss;

function createComponent(provideData = {}, shouldShowCallout = true) {
  wrapper = shallowMount(NavigationPopover, {
    provide: {
      message: ['Test'],
      observerElSelector: '.js-test',
      observerElToggledClass: 'show',
      featureName: 'attention_requests',
      popoverTarget: '.js-test-popover',
      ...provideData,
    },
    stubs: {
      UserCalloutDismisser: makeMockUserCalloutDismisser({
        dismiss,
        shouldShowCallout,
      }),
      GlSprintf,
    },
  });
}

describe('Attention requests navigation popover', () => {
  beforeEach(() => {
    setFixtures('<div><div class="js-test-popover"></div><div class="js-test"></div></div>');
    dismiss = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('hides popover if callout is disabled', () => {
    createComponent({}, false);

    expect(wrapper.findComponent(GlPopover).exists()).toBe(false);
  });

  it('shows popover if callout is enabled', () => {
    createComponent();

    expect(wrapper.findComponent(GlPopover).exists()).toBe(true);
  });

  it.each`
    isDesktop | device       | expectedPlacement
    ${true}   | ${'desktop'} | ${'left'}
    ${false}  | ${'mobile'}  | ${'bottom'}
  `(
    'sets popover position to $expectedPlacement on $device',
    ({ isDesktop, expectedPlacement }) => {
      jest.spyOn(bp, 'isDesktop').mockReturnValue(isDesktop);

      createComponent();

      expect(wrapper.findComponent(GlPopover).props('placement')).toBe(expectedPlacement);
    },
  );

  it('calls dismiss when clicking action button', () => {
    createComponent();

    wrapper
      .findComponent(GlButton)
      .vm.$emit('click', { preventDefault() {}, stopPropagation() {} });

    expect(dismiss).toHaveBeenCalled();
  });

  it('shows icon in text', () => {
    createComponent({ showAttentionIcon: true, message: ['%{strongStart}Test%{strongEnd}'] });

    const icon = wrapper.findComponent(GlIcon);

    expect(icon.exists()).toBe(true);
    expect(icon.props('name')).toBe('attention');
  });
});
