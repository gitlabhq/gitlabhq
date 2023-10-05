import { GlTable, GlFormInput } from '@gitlab/ui';
import { nextTick } from 'vue';
import { merge } from 'lodash';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import JSONTable from '~/behaviors/components/json_table.vue';

const TEST_FIELDS = [
  'A',
  {
    key: 'B',
    label: 'Second',
    sortable: true,
    other: 'foo',
    class: 'someClass',
  },
  {
    key: 'C',
    label: 'Third',
  },
  'D',
];
const TEST_ITEMS = [
  { A: 1, B: 'lorem', C: 2, D: null, E: 'dne' },
  { A: 2, B: 'ipsum', C: 2, D: null, E: 'dne' },
  { A: 3, B: 'dolar', C: 2, D: null, E: 'dne' },
];

describe('behaviors/components/json_table', () => {
  let wrapper;

  const buildWrapper = ({
    fields = [],
    items = [],
    filter = undefined,
    caption = undefined,
  } = {}) => {
    wrapper = shallowMountExtended(JSONTable, {
      propsData: {
        fields,
        items,
        hasFilter: filter,
        caption,
      },
      stubs: {
        GlTable: merge(stubComponent(GlTable), {
          props: {
            fields: {
              type: Array,
              required: true,
            },
            items: {
              type: Array,
              required: true,
            },
          },
          template: RENDER_ALL_SLOTS_TEMPLATE,
        }),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableCaption = () => wrapper.findByTestId('slot-table-caption');
  const findFilterInput = () => wrapper.findComponent(GlFormInput);

  describe('default', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders gltable', () => {
      expect(findTable().props()).toMatchObject({
        fields: [],
        items: [],
      });
      expect(findTable().attributes()).toMatchObject({
        filter: '',
        'show-empty': '',
      });
    });

    it('does not render filter input', () => {
      expect(findFilterInput().exists()).toBe(false);
    });

    it('renders caption', () => {
      expect(findTableCaption().text()).toBe('Generated with JSON data');
    });
  });

  describe('with filter', () => {
    beforeEach(() => {
      buildWrapper({
        filter: true,
      });
    });

    it('renders filter input', () => {
      expect(findFilterInput().attributes()).toMatchObject({
        value: '',
        placeholder: 'Type to search',
      });
    });

    it('when input is changed, updates table filter', async () => {
      findFilterInput().vm.$emit('input', 'New value!');

      await nextTick();

      expect(findTable().attributes('filter')).toBe('New value!');
    });
  });

  describe('with fields', () => {
    beforeEach(() => {
      buildWrapper({
        fields: TEST_FIELDS,
        items: TEST_ITEMS,
      });
    });

    it('passes cleaned fields and items to table', () => {
      expect(findTable().props()).toMatchObject({
        fields: [
          'A',
          {
            key: 'B',
            label: 'Second',
            sortable: true,
            class: 'someClass',
          },
          {
            key: 'C',
            label: 'Third',
            sortable: false,
            class: [],
          },
          'D',
        ],
        items: TEST_ITEMS,
      });
    });
  });

  describe('with full mount', () => {
    beforeEach(() => {
      wrapper = mountExtended(JSONTable, {
        propsData: {
          fields: [],
          items: [],
        },
      });
    });

    // We want to make sure all the props are passed down nicely in integration
    it('renders table without errors', () => {
      expect(findTable().exists()).toBe(true);
    });
  });
});
