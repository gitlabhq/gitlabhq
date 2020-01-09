import { mount } from '@vue/test-utils';

import DroplabDropdownButton from '~/vue_shared/components/droplab_dropdown_button.vue';

const mockActions = [
  {
    title: 'Foo',
    description: 'Some foo action',
  },
  {
    title: 'Bar',
    description: 'Some bar action',
  },
];

const createComponent = ({
  size = '',
  dropdownClass = '',
  actions = mockActions,
  defaultAction = 0,
}) =>
  mount(DroplabDropdownButton, {
    propsData: {
      size,
      dropdownClass,
      actions,
      defaultAction,
    },
  });

describe('DroplabDropdownButton', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('data', () => {
    it('contains `selectedAction` representing value of `defaultAction` prop', () => {
      expect(wrapper.vm.selectedAction).toBe(0);
    });
  });

  describe('computed', () => {
    describe('selectedActionTitle', () => {
      it('returns string containing title of selected action', () => {
        wrapper.setData({ selectedAction: 0 });

        expect(wrapper.vm.selectedActionTitle).toBe(mockActions[0].title);

        wrapper.setData({ selectedAction: 1 });

        expect(wrapper.vm.selectedActionTitle).toBe(mockActions[1].title);
      });
    });

    describe('buttonSizeClass', () => {
      it('returns string containing button sizing class based on `size` prop', done => {
        const wrapperWithSize = createComponent({
          size: 'sm',
        });

        wrapperWithSize.vm.$nextTick(() => {
          expect(wrapperWithSize.vm.buttonSizeClass).toBe('btn-sm');

          done();
          wrapperWithSize.destroy();
        });
      });
    });
  });

  describe('methods', () => {
    describe('handlePrimaryActionClick', () => {
      it('emits `onActionClick` event on component with selectedAction object as param', () => {
        jest.spyOn(wrapper.vm, '$emit');

        wrapper.setData({ selectedAction: 0 });
        wrapper.vm.handlePrimaryActionClick();

        expect(wrapper.vm.$emit).toHaveBeenCalledWith('onActionClick', mockActions[0]);
      });
    });

    describe('handleActionClick', () => {
      it('emits `onActionSelect` event on component with selectedAction index as param', () => {
        jest.spyOn(wrapper.vm, '$emit');

        wrapper.vm.handleActionClick(1);

        expect(wrapper.vm.$emit).toHaveBeenCalledWith('onActionSelect', 1);
      });
    });
  });

  describe('template', () => {
    it('renders default action button', () => {
      const defaultButton = wrapper.findAll('.btn').at(0);

      expect(defaultButton.text()).toBe(mockActions[0].title);
    });

    it('renders dropdown button', () => {
      const dropdownButton = wrapper.findAll('.dropdown-toggle').at(0);

      expect(dropdownButton.isVisible()).toBe(true);
    });

    it('renders dropdown actions', () => {
      const dropdownActions = wrapper.findAll('.dropdown-menu li button');

      Array(dropdownActions.length)
        .fill()
        .forEach((_, index) => {
          const actionContent = dropdownActions.at(index).find('.description');

          expect(actionContent.find('strong').text()).toBe(mockActions[index].title);
          expect(actionContent.find('p').text()).toBe(mockActions[index].description);
        });
    });

    it('renders divider between dropdown actions', () => {
      const dropdownDivider = wrapper.find('.dropdown-menu .divider');

      expect(dropdownDivider.isVisible()).toBe(true);
    });
  });
});
