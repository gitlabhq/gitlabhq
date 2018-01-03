/*
The squash-before-merge button is EE only, but it's located right in the middle
of the readyToMerge state component template.

If we didn't declare this component in CE, we'd need to maintain a separate copy
of the readyToMergeState template in EE, which is pretty big and likely to change.

Instead, in CE, we declare the component, but it's hidden and is configured to do nothing.
In EE, the configuration extends this object to add a functioning squash-before-merge
button.
*/

export default {
  template: '',
};
