/**
 * Highlights the current user in existing elements with a user ID data attribute.
 *
 * @param elements DOM elements that represent user mentions
 */
export default function highlightCurrentUser(elements) {
  const currentUserId = gon && gon.current_user_id;
  if (!currentUserId) {
    return;
  }

  elements.forEach((element) => {
    if (parseInt(element.dataset.user, 10) === currentUserId) {
      element.classList.add('current-user');
    }
  });
}
