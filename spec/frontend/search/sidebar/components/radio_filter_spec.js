import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import RadioFilter from '~/search/sidebar/components/shared/radio_filter.vue';

Vue.use(Vuex);

describe('RadioFilter', () => {
  let wrapper;

  const actionSpies = {
    setQuery: jest.fn(),
  };

  const defaultGetters = {
    currentScope: jest.fn(() => 'issues'),
  };

  const defaultProps = {
    filtersArray: {
      issues: [
        {
          label: 'Any',
          value: null,
        },
        {
          label: 'Confidential',
          value: 'yes',
        },
        {
          label: 'Not confidential',
          value: 'no',
        },
      ],
    },
    header: 'Confidentiality',
    filterParam: 'confidential',
  };

  const statusDefaultProps = {
    filtersArray: {
      issues: [
        {
          label: 'Any',
          value: null,
        },
        {
          label: 'Open',
          value: 'opened',
        },
        {
          label: 'Closed',
          value: 'closed',
        },
      ],
      merge_requests: [
        {
          label: 'Any',
          value: null,
        },
        {
          label: 'Open',
          value: 'opened',
        },
        {
          label: 'Merged',
          value: 'merged',
        },
        {
          label: 'Closed',
          value: 'closed',
        },
      ],
    },
    header: 'Status',
    filterParam: 'state',
  };

  const createComponent = (initialState = {}, props = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: defaultGetters,
    });

    wrapper = shallowMount(RadioFilter, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlRadioButtonGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findGlRadioButtons = () => findGlRadioButtonGroup().findAllComponents(GlFormRadio);
  const findGlRadioButtonsText = () => findGlRadioButtons().wrappers.map((w) => w.text());

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlRadioButtonGroup always', () => {
      expect(findGlRadioButtonGroup().exists()).toBe(true);
    });

    describe('Radio Buttons', () => {
      describe('Status Filter', () => {
        beforeEach(() => {
          createComponent({}, statusDefaultProps);
        });
        it('renders a radio button for each filterOption', () => {
          expect(findGlRadioButtonsText()).toStrictEqual(
            statusDefaultProps.filtersArray.issues.map((f) => {
              return f.value === null ? `Any ${'Status'.toLowerCase()}` : f.label;
            }),
          );
        });

        it('clicking a radio button item calls setQuery', () => {
          findGlRadioButtonGroup().vm.$emit('input', 'opened');

          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: 'state',
            value: 'opened',
          });
        });
      });

      describe('Confidentiality Filter', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders a radio button for each filterOption', () => {
          expect(findGlRadioButtonsText()).toStrictEqual(
            defaultProps.filtersArray.issues.map((f) => {
              return f.value === null ? `Any ${'Confidentiality'.toLowerCase()}` : f.label;
            }),
          );
        });

        it('clicking a radio button item calls setQuery', () => {
          findGlRadioButtonGroup().vm.$emit('input', 'closed');

          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: 'confidential',
            value: 'closed',
          });
        });
      });
    });
  });
});
