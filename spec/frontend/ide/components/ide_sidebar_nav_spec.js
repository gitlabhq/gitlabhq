import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import IdeSidebarNav from '~/ide/components/ide_sidebar_nav.vue';
import { SIDE_RIGHT, SIDE_LEFT } from '~/ide/constants';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

const TEST_TABS = [
  {
    title: 'Lorem',
    icon: 'chevron-lg-up',
    views: [{ name: 'lorem-1' }, { name: 'lorem-2' }],
  },
  {
    title: 'Ipsum',
    icon: 'chevron-lg-down',
    views: [{ name: 'ipsum-1' }, { name: 'ipsum-2' }],
  },
];
const TEST_CURRENT_INDEX = 1;
const TEST_CURRENT_VIEW = TEST_TABS[TEST_CURRENT_INDEX].views[1].name;
const TEST_OPEN_VIEW = TEST_TABS[TEST_CURRENT_INDEX].views[0];

describe('ide/components/ide_sidebar_nav', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(IdeSidebarNav, {
      propsData: {
        tabs: TEST_TABS,
        currentView: TEST_CURRENT_VIEW,
        isOpen: false,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findButtons = () => wrapper.findAll('li button');
  const findButtonsData = () =>
    findButtons().wrappers.map((button) => {
      return {
        title: button.attributes('title'),
        ariaLabel: button.attributes('aria-label'),
        classes: button.classes(),
        icon: button.findComponent(GlIcon).props('name'),
        tooltip: getBinding(button.element, 'gl-tooltip').value,
      };
    });
  const clickTab = () => findButtons().at(TEST_CURRENT_INDEX).trigger('click');

  describe.each`
    isOpen   | side          | otherSide     | classes         | classesObj                              | emitEvent  | emitArg
    ${false} | ${SIDE_LEFT}  | ${SIDE_RIGHT} | ${[]}           | ${{}}                                   | ${'open'}  | ${[TEST_OPEN_VIEW]}
    ${false} | ${SIDE_RIGHT} | ${SIDE_LEFT}  | ${['is-right']} | ${{}}                                   | ${'open'}  | ${[TEST_OPEN_VIEW]}
    ${true}  | ${SIDE_RIGHT} | ${SIDE_LEFT}  | ${['is-right']} | ${{ [TEST_CURRENT_INDEX]: ['active'] }} | ${'close'} | ${[]}
  `(
    'with side = $side, isOpen = $isOpen',
    ({ isOpen, side, otherSide, classes, classesObj, emitEvent, emitArg }) => {
      let bsTooltipHide;

      beforeEach(() => {
        createComponent({ isOpen, side });

        bsTooltipHide = jest.fn();
        wrapper.vm.$root.$on(BV_HIDE_TOOLTIP, bsTooltipHide);
      });

      it('renders buttons', () => {
        expect(findButtonsData()).toEqual(
          TEST_TABS.map((tab, index) => ({
            title: tab.title,
            ariaLabel: tab.title,
            classes: ['ide-sidebar-link', ...classes, ...(classesObj[index] || [])],
            icon: tab.icon,
            tooltip: {
              container: 'body',
              placement: otherSide,
            },
          })),
        );
      });

      it('when tab clicked, emits event', () => {
        expect(wrapper.emitted()).toEqual({});

        clickTab();

        expect(wrapper.emitted()).toEqual({
          [emitEvent]: [emitArg],
        });
      });

      it('when tab clicked, hides tooltip', () => {
        expect(bsTooltipHide).not.toHaveBeenCalled();

        clickTab();

        expect(bsTooltipHide).toHaveBeenCalled();
      });
    },
  );
});
