/* global Mousetrap */
// `mousetrap` uses amd which webpack understands but Jest does not
// Thankfully it also writes to a global export so we can es6-ify it
import 'mousetrap';

export default Mousetrap;
