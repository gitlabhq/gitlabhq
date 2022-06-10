import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateWorkItemTaskMutation from '../graphql/update_work_item_task.mutation.graphql';

export function getUpdateWorkItemMutation({ input, workItemParentId }) {
  let mutation = updateWorkItemMutation;

  const variables = {
    input,
  };

  if (workItemParentId) {
    mutation = updateWorkItemTaskMutation;
    variables.input = {
      id: workItemParentId,
      taskData: input,
    };
  }

  return {
    mutation,
    variables,
  };
}
