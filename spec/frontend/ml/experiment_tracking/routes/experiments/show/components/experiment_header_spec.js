import { GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ExperimentHeader from '~/ml/experiment_tracking/routes/experiments/show/components/experiment_header.vue';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlHelpers from '~/lib/utils/url_utility';
import { MOCK_EXPERIMENT } from '../mock_data';

const DELETE_INFO = {
  deletePath: '/delete',
  deleteConfirmationText: 'MODAL_BODY',
  actionPrimaryText: 'Delete!',
  modalTitle: 'MODAL_TITLE',
};

describe('~/ml/experiment_tracking/routes/experiments/show/components/experiment_header.vue', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = mountExtended(ExperimentHeader, {
      propsData: { title: MOCK_EXPERIMENT.name, deleteInfo: DELETE_INFO },
    });
  };

  const findDeleteButton = () => wrapper.findComponent(DeleteButton);
  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(createWrapper);

  describe('Delete', () => {
    it('shows delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('passes the right props', () => {
      expect(findDeleteButton().props()).toMatchObject(DELETE_INFO);
    });
  });

  describe('CSV download', () => {
    it('shows download CSV button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('calls the action to download the CSV', () => {
      setWindowLocation('https://blah.com/something/1?name=query&orderBy=name');
      jest.spyOn(urlHelpers, 'visitUrl').mockImplementation(() => {});

      findButton().vm.$emit('click');

      expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
      expect(urlHelpers.visitUrl).toHaveBeenCalledWith('/something/1.csv?name=query&orderBy=name');
    });
  });
});
