// any import of '@gitlab/svgs/dist/illustrations.svg' will be overridden with this
// to avoid asset duplication between sprockets and webpack
export default gon && gon.illustrations_path;
