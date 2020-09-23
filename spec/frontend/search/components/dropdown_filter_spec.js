import { shallowMount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import DropdownFilter from '~/search/components/dropdown_filter.vue';
import {
  FILTER_STATES,
  FILTER_STATES_BY_SCOPE,
  FILTER_HEADER,
  SCOPES,
} from '~/search/state_filter/constants';
import * as urlUtils from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

function createComponent(props = { scope: 'issues' }) {
  return shallowMount(DropdownFilter, {
    propsData: {
      filtersArray: FILTER_STATES_BY_SCOPE.issues,
      filters: FILTER_STATES,
      header: FILTER_HEADER,
      param: 'state',
      supportedScopes: Object.values(SCOPES),
      ...props,
    },
  });
}

describe('DropdownFilter', () => {
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
      scope               | showDropdown
      ${'issues'}         | ${true}
      ${'merge_requests'} | ${true}
      ${'projects'}       | ${false}
      ${'milestones'}     | ${false}
      ${'users'}          | ${false}
      ${'notes'}          | ${false}
      ${'wiki_blobs'}     | ${false}
      ${'blobs'}          | ${false}
    `(`dropdown`, ({ scope, showDropdown }) => {
      beforeEach(() => {
        wrapper = createComponent({ scope });
      });

      it(`does${showDropdown ? '' : ' not'} render when scope is ${scope}`, () => {
        expect(findGlDropdown().exists()).toBe(showDropdown);
      });
    });

    describe.each`
      initialFilter                 | label
      ${FILTER_STATES.ANY.value}    | ${`Any ${FILTER_HEADER}`}
      ${FILTER_STATES.OPEN.value}   | ${FILTER_STATES.OPEN.label}
      ${FILTER_STATES.CLOSED.value} | ${FILTER_STATES.CLOSED.label}
    `(`filter text`, ({ initialFilter, label }) => {
      describe(`when initialFilter is ${initialFilter}`, () => {
        beforeEach(() => {
          wrapper = createComponent({ scope: 'issues', initialFilter });
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
