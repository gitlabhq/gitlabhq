import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GkeZoneDropdown from '~/create_cluster/gke_cluster/components/gke_zone_dropdown.vue';
import { createStore } from '~/create_cluster/gke_cluster/store';
import {
  SET_PROJECT,
  SET_ZONES,
  SET_PROJECT_BILLING_STATUS,
} from '~/create_cluster/gke_cluster/store/mutation_types';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import { selectedZoneMock, selectedProjectMock, gapiZonesResponseMock } from '../mock_data';

const propsData = {
  fieldId: 'cluster_provider_gcp_attributes_gcp_zone',
  fieldName: 'cluster[provider_gcp_attributes][gcp_zone]',
};

const LABELS = {
  LOADING: 'Fetching zones',
  DISABLED: 'Select project to choose zone',
  DEFAULT: 'Select zone',
};

describe('GkeZoneDropdown', () => {
  let store;
  let wrapper;

  beforeEach(() => {
    store = createStore();
    wrapper = shallowMount(GkeZoneDropdown, { propsData, store });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('toggleText', () => {
    let dropdownButton;

    beforeEach(() => {
      dropdownButton = wrapper.find(DropdownButton);
    });

    it('returns disabled state toggle text', () => {
      expect(dropdownButton.props('toggleText')).toBe(LABELS.DISABLED);
    });

    describe('isLoading', () => {
      beforeEach(async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ isLoading: true });
        await nextTick();
      });

      it('returns loading toggle text', () => {
        expect(dropdownButton.props('toggleText')).toBe(LABELS.LOADING);
      });
    });

    describe('project is set', () => {
      beforeEach(async () => {
        wrapper.vm.$store.commit(SET_PROJECT, selectedProjectMock);
        wrapper.vm.$store.commit(SET_PROJECT_BILLING_STATUS, true);
        await nextTick();
      });

      it('returns default toggle text', () => {
        expect(dropdownButton.props('toggleText')).toBe(LABELS.DEFAULT);
      });
    });

    describe('project is selected', () => {
      beforeEach(async () => {
        wrapper.vm.setItem(selectedZoneMock);
        await nextTick();
      });

      it('returns project name if project selected', () => {
        expect(dropdownButton.props('toggleText')).toBe(selectedZoneMock);
      });
    });
  });

  describe('selectItem', () => {
    beforeEach(async () => {
      wrapper.vm.$store.commit(SET_ZONES, gapiZonesResponseMock.items);
      await nextTick();
    });

    it('reflects new value when dropdown item is clicked', async () => {
      const dropdown = wrapper.find(DropdownHiddenInput);

      expect(dropdown.attributes('value')).toBe('');

      wrapper.find('.dropdown-content button').trigger('click');

      await nextTick();
      expect(dropdown.attributes('value')).toBe(selectedZoneMock);
    });
  });
});
