import snoozeTodoMutation from './components/mutations/snooze_todo.mutation.graphql';

export function snoozeTodo(apolloClient, todo, until) {
  return apolloClient.mutate({
    mutation: snoozeTodoMutation,
    variables: {
      todoId: todo.id,
      snoozeUntil: until,
    },
    optimisticResponse: {
      todoSnooze: {
        todo: {
          id: todo.id,
          snoozedUntil: until,
          __typename: 'Todo',
        },
        errors: [],
      },
    },
  });
}
