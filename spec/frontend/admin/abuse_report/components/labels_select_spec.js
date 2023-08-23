import MockAdapter from 'axios-mock-adapter';
import { GlButton, GlDropdown, GlDropdownItem, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import LabelsSelect from '~/admin/abuse_report/components/labels_select.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import labelsQuery from '~/admin/abuse_report/components/graphql/abuse_report_labels.query.graphql';
import DropdownValue from '~/sidebar/components/labels/labels_select_widget/dropdown_value.vue';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import { createAlert } from '~/alert';
import { mockLabelsQueryResponse, mockLabel1, mockLabel2 } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Labels select component', () => {
  let mock;
  let wrapper;
  let fakeApollo;

  const selectedText = () => wrapper.find('[data-testid="selected-labels"]').text();
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEditButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(DropdownWidget);
  const findDropdownValue = () => wrapper.findComponent(DropdownValue);

  const labelsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockLabelsQueryResponse);
  const labelsQueryHandlerFailure = jest.fn().mockRejectedValue(new Error());

  const updatePath = '/admin/abuse_reports/1';

  async function openLabelsDropdown() {
    findEditButton().vm.$emit('click');
    await waitForPromises();
  }

  const selectLabel = (label) => {
    findDropdown().vm.$emit('set-option', label);
    nextTick();
  };

  const createComponent = ({ props = {}, labelsQueryHandler = labelsQueryHandlerSuccess } = {}) => {
    fakeApollo = createMockApollo([[labelsQuery, labelsQueryHandler]]);
    wrapper = shallowMount(LabelsSelect, {
      apolloProvider: fakeApollo,
      propsData: {
        report: { labels: [] },
        canEdit: true,
        ...props,
      },
      provide: {
        updatePath,
      },
      stubs: {
        GlDropdown,
        GlDropdownItem,
        DropdownWidget: stubComponent(DropdownWidget, {
          methods: { showDropdown: jest.fn() },
        }),
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    fakeApollo = null;
    mock.restore();
  });

  describe('initial load', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays loading icon', () => {
      expect(findLoadingIcon().exists()).toEqual(true);
    });

    it('disables edit button', () => {
      expect(findEditButton().props('disabled')).toEqual(true);
    });

    describe('after initial load', () => {
      beforeEach(() => {
        wrapper.setProps({ report: { labels: [mockLabel1] } });
      });

      it('does not display loading icon', () => {
        expect(findLoadingIcon().exists()).toEqual(false);
      });

      it('enables edit button', () => {
        expect(findEditButton().props('disabled')).toEqual(false);
      });

      it('renders fetched labels in DropdownValue', () => {
        expect(findDropdownValue().isVisible()).toBe(true);
        expect(findDropdownValue().props('selectedLabels')).toEqual([mockLabel1]);
      });
    });
  });

  describe('when there are no selected labels', () => {
    it('displays "None"', () => {
      createComponent();

      expect(selectedText()).toContain('None');
    });
  });

  describe('when there are selected labels', () => {
    beforeEach(() => {
      createComponent({ props: { report: { labels: [mockLabel1, mockLabel2] } } });

      mock.onPut(updatePath).reply(HTTP_STATUS_OK, {});
      jest.spyOn(axios, 'put');
    });

    it('renders selected labels in DropdownValue', () => {
      expect(findDropdownValue().isVisible()).toBe(true);
      expect(findDropdownValue().props('selectedLabels')).toEqual([mockLabel1, mockLabel2]);
    });

    it('selected labels can be removed', async () => {
      findDropdownValue().vm.$emit('onLabelRemove', mockLabel1.id);
      await nextTick();

      expect(findDropdownValue().props('selectedLabels')).toEqual([mockLabel2]);
      expect(axios.put).toHaveBeenCalledWith(updatePath, {
        label_ids: [mockLabel2.id],
      });
    });
  });

  describe('when not editing', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not trigger abuse report labels query', () => {
      expect(labelsQueryHandlerSuccess).not.toHaveBeenCalled();
    });

    it('does not render the dropdown', () => {
      expect(findDropdown().isVisible()).toBe(false);
    });
  });

  describe('when editing', () => {
    beforeEach(async () => {
      createComponent();
      await openLabelsDropdown();
    });

    it('triggers abuse report labels query', () => {
      expect(labelsQueryHandlerSuccess).toHaveBeenCalledTimes(1);
    });

    it('renders dropdown with fetched labels', () => {
      expect(findDropdown().isVisible()).toBe(true);
      expect(findDropdown().props('options')).toEqual([mockLabel1, mockLabel2]);
    });

    it('selects/deselects a label', async () => {
      await selectLabel(mockLabel1);

      expect(findDropdownValue().props('selectedLabels')).toEqual([mockLabel1]);

      await selectLabel(mockLabel1);

      expect(selectedText()).toContain('None');
    });

    it('triggers abuse report labels query when search term is set', async () => {
      findDropdown().vm.$emit('set-search', 'Dos');
      await waitForPromises();

      expect(labelsQueryHandlerSuccess).toHaveBeenCalledTimes(2);
      expect(labelsQueryHandlerSuccess).toHaveBeenCalledWith({ searchTerm: 'Dos' });
    });
  });

  describe('after edit', () => {
    const setup = async (response) => {
      mock.onPut(updatePath).reply(response, {});
      jest.spyOn(axios, 'put');

      createComponent();
      await openLabelsDropdown();
      await selectLabel(mockLabel1);

      findDropdown().vm.$emit('hide');
    };

    describe('successful save', () => {
      it('saves', async () => {
        await setup(HTTP_STATUS_OK);

        expect(axios.put).toHaveBeenCalledWith(updatePath, {
          label_ids: [mockLabel1.id],
        });
      });
    });

    describe('unsuccessful save', () => {
      it('creates an alert', async () => {
        await setup(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while updating labels.',
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });

  describe('failed abuse report labels query', () => {
    it('creates an alert', async () => {
      createComponent({ labelsQueryHandler: labelsQueryHandlerFailure });
      await openLabelsDropdown();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while searching for labels, please try again.',
      });
    });
  });
});
