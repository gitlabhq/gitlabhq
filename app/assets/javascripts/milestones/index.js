import initDatePicker from '~/behaviors/date_picker';
import Milestone from '~/milestones/milestone';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { mountMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';
import Sidebar from '~/right_sidebar';
import MountMilestoneSidebar from '~/sidebar/mount_milestone_sidebar';
import ZenMode from '~/zen_mode';
import TaskList from '~/task_list';
import { TYPE_MILESTONE } from '~/issues/constants';
import { createAlert } from '~/alert';
import { __ } from '~/locale';

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
