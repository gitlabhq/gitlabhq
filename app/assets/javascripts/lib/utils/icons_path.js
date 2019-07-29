// any import of '@gitlab/svgs/dist/icons.svg' will be overridden with this
// to avoid asset duplication between sprockets and webpack
export default gon && gon.sprite_icons;
