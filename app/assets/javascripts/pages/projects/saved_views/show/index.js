import { NAMESPACE_PROJECT } from '~/issues/constants';
import { initWorkItemsRoot } from '~/work_items';

initWorkItemsRoot({ workspaceType: NAMESPACE_PROJECT, withTabs: false });
