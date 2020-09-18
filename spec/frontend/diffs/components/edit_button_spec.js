import { shallowMount, mount } from '@vue/test-utils';
import { GlDeprecatedDropdown, GlDeprecatedDropdownItem, GlIcon } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import EditButton from '~/diffs/components/edit_button.vue';

jest.mock('lodash/uniqueId', () => (str = '') => `${str}fake`);

const TOOLTIP_ID = 'edit_button_tooltip_fake';
const EDIT_ITEM = {
  href: 'test-path',
  text: 'Edit in single-file editor',
};
const IDE_EDIT_ITEM = {
  href: 'ide-test-path',
  text: 'Edit in Web IDE',
};

describe('EditButton', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(EditButton, {
      propsData: {
        editPath: EDIT_ITEM.href,
        ideEditPath: IDE_EDIT_ITEM.href,
        canCurrentUserFork: false,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip').value;
  const findDropdown = () => wrapper.find(GlDeprecatedDropdown);
  const parseDropdownItems = () =>
    wrapper.findAll(GlDeprecatedDropdownItem).wrappers.map(x => ({
      text: x.text(),
      href: x.attributes('href'),
    }));
  const triggerShow = () => {
    const event = new Event('');
    jest.spyOn(event, 'preventDefault');

    findDropdown().vm.$emit('show', event);

    return event;
  };

  it.each`
    props                  | expectedItems
    ${{}}                  | ${[EDIT_ITEM, IDE_EDIT_ITEM]}
    ${{ editPath: '' }}    | ${[IDE_EDIT_ITEM]}
    ${{ ideEditPath: '' }} | ${[EDIT_ITEM]}
  `('should render items with=$props', ({ props, expectedItems }) => {
    createComponent(props);

    expect(parseDropdownItems()).toEqual(expectedItems);
  });

  describe('with default', () => {
    beforeEach(() => {
      createComponent({}, mount);
    });

    it('does not have tooltip', () => {
      expect(getTooltip()).toEqual({ id: TOOLTIP_ID, title: 'Edit file in...' });
    });

    it('shows pencil dropdown', () => {
      expect(wrapper.find(GlIcon).props('name')).toBe('pencil');
      expect(wrapper.find('.gl-dropdown-caret').exists()).toBe(true);
    });

    describe.each`
      event     | expectedEmit | expectedRootEmit
      ${'show'} | ${'open'}    | ${[['bv::hide::tooltip', TOOLTIP_ID]]}
      ${'hide'} | ${'close'}   | ${[]}
    `('when dropdown emits $event', ({ event, expectedEmit, expectedRootEmit }) => {
      let rootEmitSpy;

      beforeEach(() => {
        rootEmitSpy = jest.spyOn(wrapper.vm.$root, '$emit');

        findDropdown().vm.$emit(event);
      });

      it(`emits ${expectedEmit}`, () => {
        expect(wrapper.emitted(expectedEmit)).toEqual([[]]);
      });

      it(`emits root = ${JSON.stringify(expectedRootEmit)}`, () => {
        expect(rootEmitSpy.mock.calls).toEqual(expectedRootEmit);
      });
    });
  });

  describe('with cant modify blob and can fork', () => {
    beforeEach(() => {
      createComponent({
        canModifyBlob: false,
        canCurrentUserFork: true,
      });
    });

    it('when try to open, emits showForkMessage', () => {
      expect(wrapper.emitted('showForkMessage')).toBeUndefined();

      const event = triggerShow();

      expect(wrapper.emitted('showForkMessage')).toEqual([[]]);
      expect(event.preventDefault).toHaveBeenCalled();
      expect(wrapper.emitted('open')).toBeUndefined();
    });
  });

  describe('with editPath is falsey', () => {
    beforeEach(() => {
      createComponent({
        editPath: '',
      });
    });

    it('should disable dropdown', () => {
      expect(findDropdown().attributes('disabled')).toBe('true');
    });

    it('should have tooltip', () => {
      expect(getTooltip()).toEqual({
        id: TOOLTIP_ID,
        title: "Can't edit as source branch was deleted",
      });
    });
  });
});
