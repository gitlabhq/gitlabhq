import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
import DropdownContents from '~/vue_shared/components/color_select_dropdown/dropdown_contents.vue';
import DropdownValue from '~/vue_shared/components/color_select_dropdown/dropdown_value.vue';
import epicColorQuery from '~/vue_shared/components/color_select_dropdown/graphql/epic_color.query.graphql';
import updateEpicColorMutation from '~/vue_shared/components/color_select_dropdown/graphql/epic_update_color.mutation.graphql';
import ColorSelectRoot from '~/vue_shared/components/color_select_dropdown/color_select_root.vue';
import { DROPDOWN_VARIANT } from '~/vue_shared/components/color_select_dropdown/constants';
import { colorQueryResponse, updateColorMutationResponse, color } from './mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const successfulQueryHandler = jest.fn().mockResolvedValue(colorQueryResponse);
const successfulMutationHandler = jest.fn().mockResolvedValue(updateColorMutationResponse);
const errorQueryHandler = jest.fn().mockRejectedValue('Error fetching epic color.');
const errorMutationHandler = jest.fn().mockRejectedValue('An error occurred while updating color.');

const defaultProps = {
  allowEdit: true,
  iid: '1',
  fullPath: 'workspace-1',
};

describe('LabelsSelectRoot', () => {
  let wrapper;

  const findSidebarEditableItem = () => wrapper.findComponent(SidebarEditableItem);
  const findDropdownValue = () => wrapper.findComponent(DropdownValue);
  const findDropdownContents = () => wrapper.findComponent(DropdownContents);

  const createComponent = ({
    queryHandler = successfulQueryHandler,
    mutationHandler = successfulMutationHandler,
    propsData,
  } = {}) => {
    const mockApollo = createMockApollo([
      [epicColorQuery, queryHandler],
      [updateEpicColorMutation, mutationHandler],
    ]);

    wrapper = shallowMount(ColorSelectRoot, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      provide: {
        canUpdate: true,
      },
      stubs: {
        SidebarEditableItem,
      },
    });
  };

  describe('template', () => {
    const defaultClasses = ['labels-select-wrapper', 'gl-relative'];

    it.each`
      variant       | cssClass
      ${'sidebar'}  | ${defaultClasses}
      ${'embedded'} | ${[...defaultClasses, 'is-embedded']}
    `(
      'renders component root element with CSS class `$cssClass` when variant is "$variant"',
      ({ variant, cssClass }) => {
        createComponent({
          propsData: { variant },
        });

        expect(wrapper.classes()).toEqual(cssClass);
      },
    );
  });

  describe('if the variant is `sidebar`', () => {
    it('renders SidebarEditableItem component', () => {
      createComponent();

      expect(findSidebarEditableItem().exists()).toBe(true);
    });

    it('renders correct props for the SidebarEditableItem component', () => {
      createComponent();

      expect(findSidebarEditableItem().props()).toMatchObject({
        title: wrapper.vm.$options.i18n.widgetTitle,
        canEdit: defaultProps.allowEdit,
        loading: true,
      });
    });

    describe('when colors are loaded', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('passes false `loading` prop to sidebar editable item', () => {
        expect(findSidebarEditableItem().props('loading')).toBe(false);
      });

      it('renders dropdown value component when query colors is resolved', () => {
        expect(findDropdownValue().props('selectedColor')).toMatchObject(color);
      });
    });
  });

  describe('if the variant is `embedded`', () => {
    beforeEach(() => {
      createComponent({ propsData: { iid: undefined, variant: DROPDOWN_VARIANT.Embedded } });
    });

    it('renders DropdownContents component', () => {
      expect(findDropdownContents().exists()).toBe(true);
    });

    it('renders correct props for the DropdownContents component', () => {
      expect(findDropdownContents().props()).toMatchObject({
        variant: DROPDOWN_VARIANT.Embedded,
        dropdownTitle: wrapper.vm.$options.i18n.assignColor,
        dropdownButtonText: wrapper.vm.$options.i18n.dropdownButtonText,
      });
    });

    it('handles DropdownContents setColor', () => {
      findDropdownContents().vm.$emit('setColor', color);
      expect(wrapper.emitted('updateSelectedColor')).toEqual([[{ color }]]);
    });
  });

  describe('when epicColorQuery errored', () => {
    beforeEach(async () => {
      createComponent({ queryHandler: errorQueryHandler });
      await waitForPromises();
    });

    it('creates alert with error message', () => {
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        message: 'Error fetching epic color.',
      });
    });
  });

  it('emits `updateSelectedColor` event on dropdown contents `setColor` event if iid is not set', () => {
    createComponent({ propsData: { iid: undefined } });

    findDropdownContents().vm.$emit('setColor', color);
    expect(wrapper.emitted('updateSelectedColor')).toEqual([[{ color }]]);
  });

  describe('when updating color for epic', () => {
    const setup = () => {
      createComponent();
      findDropdownContents().vm.$emit('setColor', color);
    };

    it('sets the loading state', () => {
      setup();

      expect(findSidebarEditableItem().props('loading')).toBe(true);
    });

    it('updates color correctly after successful mutation', async () => {
      setup();

      await waitForPromises();
      expect(findDropdownValue().props('selectedColor').color).toEqual(
        updateColorMutationResponse.data.updateIssuableColor.issuable.color,
      );
    });

    it('displays an error if mutation was rejected', async () => {
      createComponent({ mutationHandler: errorMutationHandler });
      findDropdownContents().vm.$emit('setColor', color);
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: expect.anything(),
        message: 'An error occurred while updating color.',
      });
    });
  });
});
