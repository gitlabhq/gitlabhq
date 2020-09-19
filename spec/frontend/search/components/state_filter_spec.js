import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import StateFilter from '~/search/state_filter/components/state_filter.vue';
import {
  FILTER_STATES,
  SCOPES,
  FILTER_STATES_BY_SCOPE,
  FILTER_TEXT,
} from '~/search/state_filter/constants';
import * as urlUtils from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

function createComponent(props = { scope: 'issues' }) {
  return shallowMount(StateFilter, {
    propsData: {
      ...props,
    },
  });
}

describe('StateFilter', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownItems = () => findGlDropdown().findAll(GlDropdownItem);
  const findDropdownItemsText = () => findGlDropdownItems().wrappers.map(w => w.text());
  const firstDropDownItem = () => findGlDropdownItems().at(0);

  describe('template', () => {
    describe.each`
      scope               | showStateDropdown
      ${'issues'}         | ${true}
      ${'merge_requests'} | ${true}
      ${'projects'}       | ${false}
      ${'milestones'}     | ${false}
      ${'users'}          | ${false}
      ${'notes'}          | ${false}
      ${'wiki_blobs'}     | ${false}
      ${'blobs'}          | ${false}
    `(`state dropdown`, ({ scope, showStateDropdown }) => {
      beforeEach(() => {
        wrapper = createComponent({ scope });
      });

      it(`does${showStateDropdown ? '' : ' not'} render when scope is ${scope}`, () => {
        expect(findGlDropdown().exists()).toBe(showStateDropdown);
      });
    });

    describe.each`
      state                         | label
      ${FILTER_STATES.ANY.value}    | ${FILTER_TEXT}
      ${FILTER_STATES.OPEN.value}   | ${FILTER_STATES.OPEN.label}
      ${FILTER_STATES.CLOSED.value} | ${FILTER_STATES.CLOSED.label}
      ${FILTER_STATES.MERGED.value} | ${FILTER_STATES.MERGED.label}
    `(`filter text`, ({ state, label }) => {
      describe(`when state is ${state}`, () => {
        beforeEach(() => {
          wrapper = createComponent({ scope: 'issues', state });
        });

        it(`sets dropdown label to ${label}`, () => {
          expect(findGlDropdown().attributes('text')).toBe(label);
        });
      });
    });

    describe('Filter options', () => {
      it('renders a dropdown item for each filterOption', () => {
        expect(findDropdownItemsText()).toStrictEqual(
          FILTER_STATES_BY_SCOPE[SCOPES.ISSUES].map(v => {
            return v.label;
          }),
        );
      });

      it('clicking a dropdown item calls setUrlParams', () => {
        const state = FILTER_STATES[Object.keys(FILTER_STATES)[0]].value;
        firstDropDownItem().vm.$emit('click');

        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ state });
      });

      it('clicking a dropdown item calls visitUrl', () => {
        firstDropDownItem().vm.$emit('click');

        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });
});
