import Vue from 'vue';
import initDatePicker from '~/behaviors/date_picker';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import Milestone from '~/milestones/milestone';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { mountMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';
import Sidebar from '~/right_sidebar';
import MountMilestoneSidebar from '~/sidebar/mount_milestone_sidebar';
import Translate from '~/vue_shared/translate';
import ZenMode from '~/zen_mode';
import TaskList from '~/task_list';
import { TYPE_MILESTONE } from '~/issues/constants';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import DeleteMilestoneModal from './components/delete_milestone_modal.vue';
import PromoteMilestoneModal from './components/promote_milestone_modal.vue';
import eventHub from './event_hub';

// See app/views/shared/milestones/_description.html.haml
export const MILESTONE_DESCRIPTION_ELEMENT = '.milestone-detail .description';
export const MILESTONE_DESCRIPTION_TASK_LIST_CONTAINER_ELEMENT = `${MILESTONE_DESCRIPTION_ELEMENT}.js-task-list-container`;
export const MILESTONE_DETAIL_ELEMENT = '.milestone-detail';

export function initForm() {
  mountMarkdownEditor();
  new ZenMode(); // eslint-disable-line no-new
  initDatePicker();
}

export function initShow() {
  new Milestone(); // eslint-disable-line no-new
  new Sidebar(); // eslint-disable-line no-new
  new MountMilestoneSidebar(); // eslint-disable-line no-new

  renderGFM(document.querySelector(MILESTONE_DESCRIPTION_ELEMENT));

  const el = document.querySelector(MILESTONE_DESCRIPTION_TASK_LIST_CONTAINER_ELEMENT);

  if (!el) {
    return null;
  }

  return new TaskList({
    dataType: TYPE_MILESTONE,
    fieldName: 'description',
    selector: MILESTONE_DETAIL_ELEMENT,
    lockVersion: el.dataset.lockVersion,
    onError: () => {
      createAlert({
        message: __(
          'Someone edited this milestone at the same time you did. Please refresh the page to see changes.',
        ),
      });
    },
  });
}

export function initPromoteMilestoneModal() {
  Vue.use(Translate);

  const promoteMilestoneModal = document.getElementById('promote-milestone-modal');
  if (!promoteMilestoneModal) {
    return null;
  }

  return new Vue({
    el: promoteMilestoneModal,
    name: 'PromoteMilestoneModalRoot',
    render(createElement) {
      return createElement(PromoteMilestoneModal);
    },
  });
}

export function initDeleteMilestoneModal() {
  Vue.use(Translate);

  const onRequestFinished = ({ milestoneUrl, successful }) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );

    if (!successful) {
      button.removeAttribute('disabled');
    }
  };

  const deleteMilestoneButtons = document.querySelectorAll('.js-delete-milestone-button');

  const onRequestStarted = (milestoneUrl) => {
    const button = document.querySelector(
      `.js-delete-milestone-button[data-milestone-url="${milestoneUrl}"]`,
    );
    button.setAttribute('disabled', '');
    eventHub.$once('deleteMilestoneModal.requestFinished', onRequestFinished);
  };

  return new Vue({
    el: '#js-delete-milestone-modal',
    name: 'DeleteMilestoneModalRoot',
    data() {
      return {
        modalProps: {
          milestoneId: -1,
          milestoneTitle: '',
          milestoneUrl: '',
          issueCount: -1,
          mergeRequestCount: -1,
        },
      };
    },
    mounted() {
      eventHub.$on('deleteMilestoneModal.props', this.setModalProps);
      deleteMilestoneButtons.forEach((button) => {
        button.removeAttribute('disabled');
        button.addEventListener('click', () => {
          this.$root.$emit(BV_SHOW_MODAL, 'delete-milestone-modal');
          eventHub.$once('deleteMilestoneModal.requestStarted', onRequestStarted);

          this.setModalProps({
            milestoneId: parseInt(button.dataset.milestoneId, 10),
            milestoneTitle: button.dataset.milestoneTitle,
            milestoneUrl: button.dataset.milestoneUrl,
            issueCount: parseInt(button.dataset.milestoneIssueCount, 10),
            mergeRequestCount: parseInt(button.dataset.milestoneMergeRequestCount, 10),
          });
        });
      });
    },
    methods: {
      setModalProps(modalProps) {
        this.modalProps = modalProps;
      },
    },
    render(createElement) {
      return createElement(DeleteMilestoneModal, {
        props: this.modalProps,
      });
    },
  });
}
